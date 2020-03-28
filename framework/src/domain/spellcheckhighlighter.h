/*
    Copyright (c) 2020 Christian Mollekopf <mollekopf@kolabsystems.com>

    This library is free software; you can redistribute it and/or modify it
    under the terms of the GNU Library General Public License as published by
    the Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    This library is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
    License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to the
    Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301, USA.
*/
#pragma once

#include <QTextDocument>
#include <QSyntaxHighlighter>
#include <Sonnet/Speller>
#include <Sonnet/GuessLanguage>

class SpellcheckHighlighter: public QSyntaxHighlighter
{
public:
    SpellcheckHighlighter(QTextDocument *parent);

protected:
    void highlightBlock(const QString &text);

private:
    void autodetectLanguage(const QString &sentence);
    QTextCharFormat mErrorFormat;
    QTextCharFormat mQuoteFormat;
    QScopedPointer<Sonnet::Speller> mSpellchecker;
    QScopedPointer<Sonnet::GuessLanguage> mLanguageGuesser;
};